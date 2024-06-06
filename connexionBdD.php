<?php 
class Connexion{
    private $db;

    public function __construct(){
        $db_config['SGBD'] = 'mysql';
        $db_config['HOST'] = 'localhost:3306';
        $db_config['DB_NAME'] = 'INSIGHT-MOBILITY';
        $db_config['USER'] = 'root';
        $db_config['PASSWORD'] = 'FghRty963/'; //Attention : mot de passe en clair !

        try{
            $this->db = new PDO( $db_config['SGBD'].':host='.$db_config['HOST'].';dbname='.$db_config['DB_NAME'],
            $db_config['USER'], $db_config['PASSWORD']);
            unset($db_config);
        }
        catch( Exception $exception ) {
            die($exception->getMessage());
        } 
    }

    function execSQL(string $req, array $valeurs = []){
        try{
            $stmt = $this->db->prepare($req);
            $stmt->execute($valeurs);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            die($e->getMessage());
        }
    }
}
$bdd = new Connexion();
header('Content-Type: application/json');
echo json_encode( $bdd->execSQL('SELECT * FROM `Users`'));

?>